FROM ghcr.io/cirruslabs/flutter:3.24.5 AS build

RUN flutter config --enable-web

WORKDIR /app

COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get --no-version-check

COPY lib/ lib/
COPY web/ web/

RUN flutter build web --release --no-tree-shake-icons

FROM nginx:stable-alpine

COPY --from=build /app/build/web /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
