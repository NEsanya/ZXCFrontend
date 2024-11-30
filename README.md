# ZXCFrontend

### Зависимости
- [Clang](https://clang.llvm.org/)
- wasm-ld (lld)
- [wasi-sdk](https://github.com/WebAssembly/wasi-sdk)
- tar, make, curl...
- [node.js](https://nodejs.org/en) + [npm](https://www.npmjs.com/)
- [tsc](https://www.typescriptlang.org/)

### Сборка

``` shell
$ make
```

После этого в папке появятся нужные index.html, index.css, index.js, index.wasm и browser_wasi
Можно запустить через `python -m http.server -d build` и проверить http://localhost:8000/index.html 
