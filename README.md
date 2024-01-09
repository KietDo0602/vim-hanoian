# Hanoian - Optimized File Jumping Library

Inspired by Harpoon from ThePrimeagen


## Installation
Use vim-plug or other alternatives to install hanoian

Plug 'kietdo0602/vim-hanoian'



## Guide 

':Hanoian.Files' - toggle Hanoian.Files Menu Window
':Hanoian.Files.Add' - Add current file to current project in cwd

':Hanoian.Projects' - toggle Hanoian.Projects Menu
':Hanoian.Projects.Add' - Add current cwd as a new Hanoian.Projects

':Hanoian.Notes' - toggle Hanoian.Notes Menu
':Hanoian.Notes.Edit' - Open note content of current file



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
All contents are stored within hanoi.json file
1. Allow storing files paths and jumping around
2. Each file has a note - txt or json - txt now only

