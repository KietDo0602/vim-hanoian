# Hanoian - File Navigation and Project Management Library
Inspired by Harpoon by ThePrimeagen


## Features:

**Navigate** between files within a project **(Hanoi.Files)**

**Switch** projects easily **(Hanoi.Projects)**

**Notes** for every files **(Hanoi.Notes)**


## Installation
Use vim-plug or other alternatives to install hanoian

```text
Plug 'kietdo0602/vim-hanoian'
```


## Commands 
':HanoianFiles' - Toggle Hanoian.Files Menu
':HanoianFilesAdd' - Add current file
':HanoianFilesRemove' - Remove current file

':HanoianProjects' - Toggle Hanoian.Projects Menu
':HanoianProjectsAdd' - Make current cwd as new Hanoian.Project
':HanoianProjectsRemove' - Remove current cwd 

':HanoianNotes' - toggle Hanoian.Notes Menu
':HanoianNotesEdit' - Open note notes of current file
':HanoianNotesDelete' - Delete all notes of current file


## Explanation

### Hanoi.Files

Hanoi.Files Menu contain all of the files stored in the project 
Add and Jump between files easily with menu

By default, when adding a new file, it will use the cwd as the root of the projects

### Hanoi.Projects

Hanoi.Projects contain all global projects stored on your machine

### Hanoi.Notes

For each file added to the Hanoi.Files, you can add notes file to it.

Edit the note of each file and save them.


## Cusomization
To customize settings, change content of the settings key of json inside '~/hanoi.json'


## Implementation
All settings are stored within hanoi-settings.json file
All files the user are stored within hanoi.json file

1. Allow storing files paths and jumping around
2. Each file has a note - txt or json - txt now only

