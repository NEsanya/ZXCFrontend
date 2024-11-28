const wasmInitializedCheck = (): boolean =>
    (window as any).wasm && (window as any).browserWasi;
async function initializeWasm(): Promise<void> {
    if (wasmInitializedCheck())
        throw new Error("Wasm Bytecode or browser_wasi is already initialized");

    (window as any).wasm = await WebAssembly.compileStreaming(fetch("./index.wasm"));
    //@ts-ignore
    (window as any).browserWasi = await import("./browser_wasi/index.js");
}
function startWasmModule(args: string[], error_cb: (arg: string) => void): Promise<void> {
    return new Promise((resolve, reject) => {
        if (!wasmInitializedCheck())
            reject(new Error("Initialize wasm module"));

        const { WASI, File, OpenFile, ConsoleStdout } = (window as any).browserWasi;

        const fds = [
            new OpenFile(new File([])),
            ConsoleStdout.lineBuffered((msg: string) =>
                msg == "done" ? resolve(undefined) :console.log(`${msg}`)
            ),
            ConsoleStdout.lineBuffered(error_cb),
            []
        ];

        const wasi = new WASI(args, [], fds);
        WebAssembly.instantiate((window as any).wasm, {
            env: {
                memory: new WebAssembly.Memory({
                    initial: 1024,
                    maximum: 8192,
                    shared: false
                }),
                concurrency: () => navigator.hardwareConcurrency
            },
            wasi_snapshot_preview1: wasi.wasiImport
        }).then((inst) => wasi.start(inst));
    })
}

(async () => {
    await initializeWasm();
    await startWasmModule(
        [JSON.stringify({"test1": "test2"})],
        (error: string) => console.warn(`ERROR: ${error}`)
    );
})()
