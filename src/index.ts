let wasm: any = null
let browserWasi: any = null
const wasmInitializedCheck = (): boolean =>
    wasm && browserWasi;

async function initializeWasm(): Promise<void> {
    if (wasmInitializedCheck())
        throw new Error("Wasm Bytecode or browser_wasi is already initialized");

    wasm = await WebAssembly.compileStreaming(fetch("./index.wasm"));
    //@ts-ignore
    browserWasi = await import("./browser_wasi/index.js");
}
function startWasmModule(args: string[], error_cb: (arg: string) => void): Promise<void> {
    return new Promise((resolve, reject) => {
        if (!wasmInitializedCheck())
            reject(new Error("Initialize wasm module"));

        const { WASI, File, OpenFile, ConsoleStdout } = browserWasi;

        const fds = [
            new OpenFile(new File([])),
            ConsoleStdout.lineBuffered((msg: string) =>
                msg == "done" ? resolve(undefined) : console.log(`${msg}`)
            ),
            ConsoleStdout.lineBuffered(error_cb),
            []
        ];

        const wasi = new WASI(args, [], fds);
        WebAssembly.instantiate(wasm, {
            env: {
                memory: new WebAssembly.Memory({
                    initial: 8192,
                    maximum: 65536,
                    shared: false
                }),
                dataLength: () => 256
            },
            wasi_snapshot_preview1: wasi.wasiImport
        }).then((inst) => wasi.start(inst));
    })
}

(async () => {
	await initializeWasm();
	await startWasmModule([], console.warn);
})()
