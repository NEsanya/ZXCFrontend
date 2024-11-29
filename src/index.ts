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
function startWasmModule(args: string, error_cb: (arg: string) => void): Promise<void> {
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

        const encoder = new TextEncoder();
        const encodedString = encoder.encode(args);

        const wasi = new WASI(args, [], fds);
        WebAssembly.instantiate(wasm, {
            env: {
                memory: new WebAssembly.Memory({
                    initial: 8192,
                    maximum: 65536,
                    shared: false
                }),
                dataLength: () => encodedString.byteLength
            },
            wasi_snapshot_preview1: wasi.wasiImport
        }).then((inst) => wasi.start(inst));
    })
}

class Offer {
    constructor (public name: string,
                 public vendor: string,
                 public price: number,
                 public description: string,
                 public barcode: number,
                 public article: number,
                 public discount: number) {}

    public toString(): string {
        return JSON.stringify({
            name: this.name,
            vendor: this.vendor,
            price: this.price,
            description: this.description,
            barcode: this.barcode,
            article: this.article,
            discount: this.discount
        });
    }
}

let offers: Offer[] = []

const vendorButtons = document.getElementById("vendor-buttons");
document.getElementById("vendor-add-button").addEventListener("click", () => {
    const newButton = document.createElement("div");
    const id = vendorButtons.childElementCount + 1
    newButton.className = "circle noselect";
    newButton.id = `vendor-button-${id}`;
    newButton.textContent = id.toString();
    vendorButtons.appendChild(newButton);
});
