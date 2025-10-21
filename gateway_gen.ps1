param (
    [string]$DestinationHost = "primary:22"
)

cargo run --manifest-path C:\\Users\\jou\\code\\devolutions-gateway\\tools\\tokengen\\Cargo.toml --target-dir C:\\Users\\jou\\code\\devolutions-gateway\\tools\\tokengen\\target -- --provisioner-key C:\\ProgramData\\Devolutions\\Gateway\\provisioner.key forward --dst-hst $DestinationHost
