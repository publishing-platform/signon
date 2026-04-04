ARG ruby_version=3.4
ARG base_image=ghcr.io/publishing-platform/publishing-platform-ruby-base:$ruby_version
ARG builder_image=ghcr.io/publishing-platform/publishing-platform-ruby-builder:$ruby_version

FROM $builder_image AS builder

ENV DEVISE_PEPPER=unused \
    DEVISE_SECRET_KEY=unused \
    PUBLISHING_PLATFORM_ENVIRONMENT_NAME=unused

WORKDIR $APP_HOME
COPY Gemfile* .ruby-version ./
RUN bundle install
COPY package.json yarn.lock ./
RUN yarn install
COPY . .
RUN bootsnap precompile --gemfile .
RUN rails assets:precompile && rm -fr log

FROM $base_image

ENV PUBLISHING_PLATFORM_APP_NAME=signon

WORKDIR $APP_HOME
COPY --from=builder $BUNDLE_PATH $BUNDLE_PATH
COPY --from=builder $BOOTSNAP_CACHE_DIR $BOOTSNAP_CACHE_DIR
COPY --from=builder $APP_HOME .

USER app
CMD ["puma"]