import {
  JupyterFrontEnd,
  JupyterFrontEndPlugin
} from '@jupyterlab/application';

import {
  ICommandPalette,
  IToolbarWidgetRegistry,
  ToolbarButton
} from '@jupyterlab/apputils';

import { IMainMenu } from '@jupyterlab/mainmenu';
import { PageConfig } from '@jupyterlab/coreutils';
import { Menu } from '@lumino/widgets';

const plugin: JupyterFrontEndPlugin<void> = {
  id: 'hub-profile-switcher:plugin',
  description: 'Button to switch JupyterHub server profile',
  autoStart: true,
  requires: [IToolbarWidgetRegistry],
  optional: [IMainMenu, ICommandPalette],
  activate: (
    app: JupyterFrontEnd,
    toolbarRegistry: IToolbarWidgetRegistry,
    mainMenu: IMainMenu | null,
    palette: ICommandPalette | null
  ) => {
    const hubHost = PageConfig.getOption('hubHost') || '';
    const hubPrefix = PageConfig.getOption('hubPrefix') || '';
    const baseUrl = PageConfig.getOption('baseUrl') || '/';

    let hubHome: string;
    if (hubPrefix) {
      hubHome = `${hubHost}${hubPrefix}home`;
    } else {
      hubHome = baseUrl.replace(/\/user\/[^/]+\//, '/hub/home');
    }

    const commandId = 'hub:switch-profile';
    app.commands.addCommand(commandId, {
      label: 'Switch Server Profile',
      caption: 'Stop server and switch to a different profile',
      execute: () => { window.location.href = hubHome; }
    });

    app.commands.addKeyBinding({
      command: commandId,
      keys: ['Ctrl Shift H'],
      selector: 'body'
    });

    // ── Register in the JupyterLab 4 TopBar via toolbar widget registry ───────
    toolbarRegistry.addFactory('TopBar', 'hub-switch-profile', () => {
      return new ToolbarButton({
        label: 'Switch Profile',
        tooltip: 'Stop server and switch to a different profile (Ctrl+Shift+H)',
        onClick: () => { window.location.href = hubHome; }
      });
    });

    // ── "Hub" menu in the main menu bar ──────────────────────────────────────
    void app.restored.then(() => {
      if (mainMenu) {
        const menu = new Menu({ commands: app.commands });
        menu.title.label = 'Hub';
        menu.addItem({ command: commandId });
        mainMenu.addMenu(menu, false, { rank: 10000 });
      }

      if (palette) {
        palette.addItem({ command: commandId, category: 'Hub' });
      }
    });
  }
};

export default plugin;
