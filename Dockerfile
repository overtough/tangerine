FROM python:3.11.2-slim-bookworm

WORKDIR /workspace
COPY . .

CMD ["make", "test"]
