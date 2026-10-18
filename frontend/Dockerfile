# ---------- build stage ----------
    FROM node:20.18-alpine3.19 AS builder
    
    WORKDIR /app
    
    COPY package.json package-lock.json ./
    RUN npm ci
    
    COPY . .
    RUN npm run build
    
    # ---------- production stage ----------
    FROM nginx:1.25-alpine
    
    COPY nginx.conf /etc/nginx/conf.d/default.conf
    COPY --from=builder /app/dist/angular-conduit /usr/share/nginx/html
    
    EXPOSE 80
    
    HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
      CMD wget -q --spider http://localhost/ || exit 1
    
    STOPSIGNAL SIGQUIT