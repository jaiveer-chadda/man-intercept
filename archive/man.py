import os
import re

from typing import Callable, Final, Iterable, TypeVar
from collections import Counter


T = TypeVar('T')
U = TypeVar('U')


USER_HOME:      Final[str] = os.path.expanduser('~')
MAN_NAMES_LOC:  Final[str] = f"{USER_HOME}/Desktop/CS/y_settings_etc/Resources/Man-Pages/All-Builtins"
MAN_SECTIONS:   Final[str] = f"{MAN_NAMES_LOC}/By-Section"


SECT_PATH_IS_DIR:     Final[Callable[[str], bool]] = lambda p: os.path.isdir(os.path.join(MAN_SECTIONS, p))

FILE_IS_NOT_HIDDEN:   Final[Callable[[str], bool]] = lambda f: f[0] != '.'
STRIP_FILE_EXTENSION: Final[Callable[[str], str ]] = lambda f: f.replace(".txt", "")

REMOVE_FIRST_CHAR:    Final[Callable[[str], str ]] = lambda s: s[1:]
STRING_IS_NOT_EMPTY:  Final[Callable[[str], bool]] = lambda s: re.fullmatch("\\s*", s) is None


ALL_SECTIONS:    Final[filter[str]]     = filter(SECT_PATH_IS_DIR, os.listdir(MAN_SECTIONS))
SORTED_SECTIONS: Final[tuple[str, ...]] = tuple(sorted(ALL_SECTIONS))


all_files: list[str] = []
for section_dir in SORTED_SECTIONS:
    path:   str  = os.path.join(MAN_SECTIONS, section_dir)
    is_dir: bool = os.path.isdir(path)
    
    all_files.extend(os.listdir(path) if is_dir else [])


FILES_FILTERED:   Final[filter[str]]     = filter(FILE_IS_NOT_HIDDEN,  all_files)
FILES_STRIPPED:   Final[map[str]]        = map(STRIP_FILE_EXTENSION,   FILES_FILTERED)
FILENAMES_TUPLE:  Final[tuple[str, ...]] = tuple(FILES_STRIPPED)

ALL_SUBSECTIONS:  Final[map[str]]        = map(REMOVE_FIRST_CHAR,      FILENAMES_TUPLE)
SUBSECTS_CLEANED: Final[filter[str]]     = filter(STRING_IS_NOT_EMPTY, ALL_SUBSECTIONS)
SUBSECTS_COUNT:   Final[Counter[str]]    = Counter(SUBSECTS_CLEANED)

SUBSECTS_ORDERED: Final[tuple[str, ...]] = tuple([""] + list(SUBSECTS_COUNT.keys()))


full_subsect_name: str; sect: str; subsect: str
SUBSECTION_GRID: Final[tuple[tuple[str, ...], ...]] = tuple([
    tuple([
        full_subsect_name
        if (full_subsect_name := sect + subsect) in FILENAMES_TUPLE
        else ""
        for sect in SORTED_SECTIONS
    ])
    for subsect in SUBSECTS_ORDERED
])


def main() -> None:
    subsection_row: tuple[str, ...]
    for subsection_row in SUBSECTION_GRID:
        print(*map(lambda x: x.ljust(10), subsection_row))


if __name__ == "__main__":
    main()
