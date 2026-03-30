export type LogCallback = (msg: string) => void;

class Logger {
  private callbacks: LogCallback[] = [];

  subscribe(callback: LogCallback) {
    this.callbacks.push(callback);
    return () => {
      this.callbacks = this.callbacks.filter(cb => cb !== callback);
    };
  }

  log(msg: string) {
    console.log(msg);
    this.callbacks.forEach(cb => cb(msg));
  }

  warn(msg: string, ...args: any[]) {
    console.warn(msg, ...args);
    this.callbacks.forEach(cb => cb(`WARN: ${msg}`));
  }

  error(msg: string, ...args: any[]) {
    console.error(msg, ...args);
    this.callbacks.forEach(cb => cb(`ERROR: ${msg}`));
  }
}

export const logger = new Logger();
