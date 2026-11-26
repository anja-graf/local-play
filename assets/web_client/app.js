import { ClientApi, Poller } from './networking.js';
import { $, text, show, clearGameWidgets, renderPlayers } from './widgets.js';
import { createDefaultView } from './games/default_game.js';
import { createWerewolfView } from './games/werewolf.js';

const api = new ClientApi();
const gameViews = {
  freePlay: createDefaultView,
  president: createDefaultView,
  blackjack: createDefaultView,
  werewolf: createWerewolfView,
};
let state = null;
let busy = false;
let operation = 0;
let activeView = null;
let activeType = null;

function fail(message) { text('error', message); }
function isExpired(error) {
  return error.message.includes('Session expired') || error.message.includes('Join first');
}

function reset() {
  operation++;
  api.setToken('');
  state = null;
  activeView?.reset();
  activeView = null;
  activeType = null;
  clearGameWidgets();
  for (const id of ['title', 'status', 'info']) text(id, '');
  text('connection', 'Offline multiplayer');
  render();
}

function acceptState(next) {
  if (!state || next.version >= state.version) state = next;
}

function render() {
  $('joinForm').querySelector('button').disabled = busy;
  show('joinSection', !state && !api.token);
  show('gameSection', !!state);
  if (!state) return;
  show('leave', state.phase === 'lobby');
  $('leave').disabled = busy;
  text('title', state.title);
  text('status', state.status);
  text('info', state.info);
  if (state.phase === 'lobby') {
    activeView?.reset();
    activeView = null;
    activeType = null;
    clearGameWidgets();
    renderPlayers(state.players, state.you);
    return;
  }
  if (activeType !== state.gameType || !activeView) {
    activeView?.reset();
    activeType = state.gameType;
    activeView = (gameViews[activeType] ?? createDefaultView)();
  }
  const displayedVersion = state.version;
  activeView.render(state, { busy, rerender: render,
    onAction: action => perform(action, displayedVersion) });
}

async function poll() {
  if (!api.token || busy) return;
  const requestToken = api.token;
  const requestOperation = operation;
  try {
    const next = await api.send('state', {}, requestToken);
    if (requestToken !== api.token || requestOperation !== operation || busy) return;
    if (!state || next.version > state.version) { acceptState(next); render(); }
    text('connection', 'Connected to local host');
  } catch (error) {
    if (requestToken !== api.token || requestOperation !== operation || busy) return;
    if (isExpired(error)) { reset(); fail(error.message); }
    else text('connection', 'Connection lost — retrying…');
  }
}

async function perform(action, version) {
  if (busy || !state) return;
  busy = true;
  operation++;
  render();
  fail('');
  try {
    acceptState(await api.send('action', { ...action, version }));
    activeView?.reset();
    text('connection', 'Connected to local host');
  } catch (error) {
    fail(error.message);
    if (isExpired(error)) reset();
    else {
      // Do not automatically replay an action; the server may have applied it
      // before the response was lost. Refresh the authoritative state instead.
      try { acceptState(await api.send('state')); }
      catch (refreshError) {
        if (isExpired(refreshError)) reset();
        else text('connection', 'Connection lost — retrying…');
      }
    }
  } finally { busy = false; render(); }
}

$('joinForm').onsubmit = async event => {
  event.preventDefault();
  if (busy) return;
  busy = true;
  operation++;
  fail('');
  render();
  try {
    const data = await api.send('join', { name: $('name').value }, '');
    api.setToken(data.token);
    acceptState(await api.send('state'));
    text('connection', 'Connected to local host');
  } catch (error) {
    fail(error.message);
    if (isExpired(error)) reset();
  } finally { busy = false; render(); }
};

$('leave').onclick = async () => {
  if (busy) return;
  busy = true;
  operation++;
  render();
  try { await api.send('leave'); reset(); fail(''); }
  catch (error) { if (isExpired(error)) reset(); fail(error.message); }
  finally { busy = false; render(); }
};

render();
const poller = new Poller(poll);
poller.start();
