import { renderPrivate, renderPlayers, renderActions, show, $ } from '../widgets.js';

export function createWerewolfView() {
  return {
    reset() {},
    render(state, { busy, onAction }) {
      renderPrivate(state);
      renderPlayers(state.players, state.you);
      show('cardSection', false);
      $('hand').replaceChildren();
      $('table').replaceChildren();
      renderActions(state, { busy, onAction });
    },
  };
}
