FROM node:20-slim

RUN apt-get update && apt-get install -y \
    wget curl gnupg ca-certificates \
    fonts-liberation libasound2 libatk-bridge2.0-0 libatk1.0-0 \
    libc6 libcairo2 libcups2 libdbus-1-3 libexpat1 libfontconfig1 \
    libgbm1 libgcc1 libglib2.0-0 libgtk-3-0 libnspr4 libnss3 \
    libpango-1.0-0 libpangocairo-1.0-0 libstdc++6 \
    libx11-6 libx11-xcb1 libxcb1 libxcomposite1 libxcursor1 \
    libxdamage1 libxext6 libxfixes3 libxi6 libxrandr2 libxrender1 \
    libxss1 libxtst6 lsb-release xdg-utils \
    --no-install-recommends && rm -rf /var/lib/apt/lists/*

RUN wget -q -O /tmp/chrome.deb \
      https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb \
    && apt-get update \
    && apt-get install -y /tmp/chrome.deb \
    && rm /tmp/chrome.deb && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://packages.microsoft.com/keys/microsoft.asc \
      | gpg --dearmor -o /usr/share/keyrings/microsoft.gpg \
    && echo "deb [arch=amd64 signed-by=/usr/share/keyrings/microsoft.gpg] \
       https://packages.microsoft.com/repos/edge stable main" \
       > /etc/apt/sources.list.d/microsoft-edge.list \
    && apt-get update \
    && apt-get install -y microsoft-edge-stable \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
CMD ["npm", "test"]
