"""PyInstaller entry point with multiprocessing bootstrap before GUI imports."""

import multiprocessing


if __name__ == '__main__':
    multiprocessing.freeze_support()
    from esibd.__main__ import main

    main()
