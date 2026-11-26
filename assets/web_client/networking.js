// HTTP transport and token storage. No game rules or DOM rendering.
const TOKEN_KEY = 'localplay-token';

export class ClientApi {
  token = sessionStorage.getItem(TOKEN_KEY) || '';

  setToken(token) {
    this.token = token;
    if (token) sessionStorage.setItem(TOKEN_KEY, token);
    else sessionStorage.removeItem(TOKEN_KEY);
  }

  async send(type, payload = {}, token = this.token) {
    const headers = { 'Content-Type': 'application/json' };
    if (token) headers.Authorization = 'Bearer ' + token;
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), 6000);
    try {
      const response = await fetch('/api/message', {
        method: 'POST', headers, body: JSON.stringify({ type, payload }),
        cache: 'no-store', signal: controller.signal,
      });
      const data = await response.json();
      if (!response.ok) throw new Error(data.error || 'Request failed');
      return data;
    } catch (error) {
      if (error.name === 'AbortError') throw new Error('Request timed out');
      throw error;
    } finally {
      clearTimeout(timeout);
    }
  }
}

// A single polling loop; no overlapping poll requests.
export class Poller {
  #timer = null;
  #running = false;

  constructor(poll, interval = 900) {
    this.poll = poll;
    this.interval = interval;
  }

  start() {
    if (this.#running) return;
    this.#running = true;
    const tick = async () => {
      try { await this.poll(); }
      finally {
        if (this.#running) this.#timer = setTimeout(tick, this.interval);
      }
    };
    void tick();
  }
}
