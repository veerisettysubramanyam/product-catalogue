import { createApp } from "./app.js";
import { loadConfig } from "./config.js";

const config = loadConfig();

const app = createApp({ corsOrigin: config.CORS_ORIGIN });

app.listen(config.PORT, () => {
  console.log(`Backend listening on http://localhost:${config.PORT}`);
});
