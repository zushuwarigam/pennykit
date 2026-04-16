wget https://ftp.nluug.nl/pub/vim/runtime/spell/ru.utf-8.spl
wget https://ftp.nluug.nl/pub/vim/runtime/spell/en.utf-8.spl

You can manually edit this file to add or remove multiple words at once.
If you edit it manually, you may need to run :mkspell! % while inside the file 
to recompile the binary .spl file used by the editor.
```
:mkspell! ~/.config/nvim/spell/en.utf-8.add

```

