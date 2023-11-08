FROM node:18-alpine AS dependencies
RUN apk add --no-cache libc6-compat
WORKDIR /home/app
COPY package.json ./
COPY package-lock.json ./
RUN npm i

FROM node:18-alpine AS builder
WORKDIR /home/app
COPY --from=dependencies /home/app/node_modules ./node_modules
COPY . .
ENV NEXT_TELEMETRY_DISABLED 1
ARG NODE_ENV
ENV NODE_ENV=”${NODE_ENV}”
RUN npm run build

FROM node:18-slim AS runner

WORKDIR /home/app
ENV NEXT_TELEMETRY_DISABLED 1
ENV NODE_ENV=production
COPY --from=builder /home/app/.next/standalone ./standalone
COPY --from=builder /home/app/public /home/app/standalone/public
COPY --from=builder /home/app/.next/static /home/app/standalone/.next/static
COPY --from=builder /home/app/scripts/entrypoint.sh ./scripts/entrypoint.sh
COPY --from=builder /home/app/.env.production ./.env.production

ENV HOSTNAME "0.0.0.0"

RUN chmod +x ./scripts/entrypoint.sh

ENTRYPOINT [ "./scripts/entrypoint.sh" ]

CMD ["node", "./standalone/server.js"]
