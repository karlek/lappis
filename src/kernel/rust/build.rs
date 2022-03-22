fn main() {
    println!("cargo:rustc-link-search=.");
    println!("cargo:rustc-link-lib=kernel");

    // cc::Build::new()
    //     .file("src/num.c")
    //     .compile("anything");
}
