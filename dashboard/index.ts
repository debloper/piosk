import { PIOSK_VERSION } from "./version.ts";
const CONFIG_FILE = "./config.json";

async function readConfig(): Promise<string> {
  try {
    return await Deno.readTextFile(CONFIG_FILE);
  } catch (error) {
    if (error instanceof Deno.errors.NotFound) {
      // Return sample config if config.json doesn't exist
      return await Deno.readTextFile("./config.json.sample");
    }
    throw error;
  }
}

async function writeConfig(configData: string): Promise<void> {
  await Deno.writeTextFile(CONFIG_FILE, configData);
}

async function rebootSystem(): Promise<void> {
  try {
    // In test mode, don't actually reboot
    if (Deno.env.get("PIOSK_TEST_MODE") === "true") {
      console.log("Test mode: Would reboot system");
      return;
    }
    
    // Use absolute path to the reboot command
    const command = new Deno.Command("/sbin/reboot"); 

    // Spawn the process to run in the background and DO NOT await it. 
    command.spawn();
  } catch (error) {
    console.error("Reboot command failed:", error);
    throw error;
  }
}

async function serveStaticFile(pathname: string): Promise<Response> {
  let filePath: string;
  
  if (pathname === "/" || pathname === "/index.html") {
    filePath = "./dashboard/index.html";
  } else {
    // Remove leading slash and serve from web directory
    filePath = `./dashboard${pathname}`;
  }
  
  try {
    const file = await Deno.readFile(filePath);
    
    // Determine content type
    let contentType = "text/plain";
    if (filePath.endsWith(".html")) {
      contentType = "text/html";
    } else if (filePath.endsWith(".js")) {
      contentType = "application/javascript";
    } else if (filePath.endsWith(".css")) {
      contentType = "text/css";
    } else if (filePath.endsWith(".json")) {
      contentType = "application/json";
    }
    
    return new Response(file, {
      headers: { "Content-Type": contentType },
    });
  } catch (error) {
    if (error instanceof Deno.errors.NotFound) {
      return new Response("Not Found", { status: 404 });
    }
    console.error("Error serving file:", error);
    return new Response("Internal Server Error", { status: 500 });
  }
}

async function handler(req: Request): Promise<Response> {
  const url = new URL(req.url);
  
  // Handle API endpoints
  if (url.pathname === "/config") {
    if (req.method === "GET") {
      try {
        const config = await readConfig();
        return new Response(config, {
          headers: { "Content-Type": "application/json" },
        });
      } catch (error) {
        console.error("Error reading config:", error);
        return new Response("Could not read config.", { status: 500 });
      }
    }
    
    if (req.method === "POST") {
      try {
        const configData = await req.text();
        
        // Validate JSON
        JSON.parse(configData);
        
        await writeConfig(JSON.stringify(JSON.parse(configData), null, "  "));
        
        // Reboot system
        try {
          await rebootSystem();
          return new Response("New config applied; rebooting for changes to take effect...", { status: 200 });
        } catch (rebootError) {
          console.error("Reboot error:", rebootError);
          return new Response("Could not reboot to apply config. Retry or reboot manually.", { status: 500 });
        }
      } catch (error) {
        console.error("Error saving config:", error);
        return new Response("Could not save config.", { status: 500 });
      }
    }
  }
  
  // Handle static files
  return await serveStaticFile(url.pathname);
}

// Check if '--version' or '-v' is present in the command-line arguments.
if (Deno.args.includes("--version") || Deno.args.includes("-v")) {
  console.log(`piosk version ${PIOSK_VERSION}`);
  Deno.exit(0); // Exit successfully after printing the version.
}

const port = parseInt(Deno.env.get("PORT") || "80");
console.log(`PiOSK Deno server starting on port ${port}...`);

Deno.serve({ port }, handler);

