// Reusable DOM widgets. Insert player-controlled strings as text, never HTML.
export const $ = id => document.getElementById(id);
export const text = (id, value) => { $(id).textContent = value ?? ''; };
export const show = (id, visible) => { $(id).hidden = !visible; };

export function renderPrivate(state) {
  const img = $('privateCard');
  const asset = state?.privateCard;
  const hasCard = typeof asset === 'string' && asset.startsWith('assets/cards/');
  const privateText = state?.privateText ?? '';
  if (hasCard) {
    const src = '/' + asset;
    if (img.getAttribute('src') !== src) img.src = src;
  } else img.removeAttribute('src');
  show('privateCard', hasCard);
  text('privateText', privateText);
  show('privateText', !!privateText);
  show('privateSection', hasCard || !!privateText);
}

export function renderPlayers(players, you) {
  const box = $('players');
  box.replaceChildren();
  for (const p of players) {
    const el = document.createElement('span');
    el.className = 'chip';
    el.textContent = (p.turn ? '▶ ' : '') + p.name +
      (p.id === you ? ' (you)' : '') + (p.bot ? ' 🤖' : '') +
      (p.count != null ? ' · ' + p.count + ' cards' : '') +
      (p.note ? ' · ' + p.note : '');
    box.append(el);
  }
}

export function renderCards(id, values, { selected = new Set(), onToggle } = {}) {
  const box = $(id);
  box.replaceChildren();
  if (!values.length) { box.textContent = id === 'hand' ? 'No cards' : 'Empty'; return; }
  for (const value of values) {
    const selectable = typeof onToggle === 'function';
    const el = document.createElement(selectable ? 'button' : 'span');
    el.className = 'card' + (selectable && selected.has(value) ? ' selected' : '');
    const img = document.createElement('img');
    img.src = '/cards/' + encodeURIComponent(value) + '.svg';
    img.alt = value.replaceAll('_', ' ');
    el.append(img);
    if (selectable) {
      el.type = 'button';
      el.setAttribute('aria-pressed', String(selected.has(value)));
      el.onclick = () => onToggle(value);
    }
    box.append(el);
  }
}

export function renderActions(state, { busy, selected = new Set(), onAction }) {
  const box = $('actions');
  box.replaceChildren();
  for (const action of state.actions) {
    const b = document.createElement('button');
    b.type = 'button';
    b.textContent = action.label;
    b.disabled = busy || (action.selection && !selected.size);
    b.onclick = () => onAction(action.selection ?
      { id: action.id, cards: [...selected] } : { id: action.id, cards: [] });
    box.append(b);
  }
  if (!state.actions.length && state.phase === 'playing') {
    box.textContent = 'Waiting for other players…';
  }
}

export function clearGameWidgets() {
  renderPrivate(null);
  for (const id of ['players', 'hand', 'table', 'actions']) $(id).replaceChildren();
  show('cardSection', false);
}
