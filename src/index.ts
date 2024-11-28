// @ts-ignore
import { WASI, File, OpenFile, ConsoleStdout } from "./browser_wasi/index.js"

const fds = [
    new OpenFile(new File([])),
    ConsoleStdout.lineBuffered(msg => console.log(`${msg}`)),
    ConsoleStdout.lineBuffered(msg => console.warn(`${msg}`)),
    []
];

(async () => {
    const wasi = new WASI([], [], fds)
    const wasm = await WebAssembly.compileStreaming(fetch("./index.wasm"))
    const inst = await WebAssembly.instantiate(wasm, {
        env: {
            memory: new WebAssembly.Memory({
                initial: 1024,
                maximum: 2048,
                shared: false
            }),
            concurrency: () => navigator.hardwareConcurrency
        },
        wasi_snapshot_preview1: wasi.wasiImport
    })
    wasi.start(inst)
})()
