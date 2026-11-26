import { renderPrivate, renderPlayers, renderCards, renderActions, text, show } from '../widgets.js';

// Selection is local UI state, not session or networking state.
export function createDefaultView() {
  const selected = new Set();
  return {
    reset() { selected.clear(); },
    render(state, { busy, onAction, rerender }) {
      for (const id of selected) if (!state.hand.includes(id)) selected.delete(id);
      if (state.phase !== 'playing') selected.clear();
      renderPrivate(state);
      renderPlayers(state.players, state.you);
      show('cardSection', state.hand.length > 0 || state.table.length > 0);
      text('tableLabel', state.tableLabel);
      renderCards('table', state.table);
      const canSelect = !busy && state.actions.some(a => a.selection);
      renderCards('hand', state.hand, { selected, onToggle: canSelect ? id => {
        if (selected.has(id)) selected.delete(id); else selected.add(id);
        rerender();
      } : undefined });
      renderActions(state, { busy, selected, onAction });
    },
  };
}
