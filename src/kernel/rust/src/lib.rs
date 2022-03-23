#![no_std]
#![no_main]

#[link(name = "kernel")]
extern "C" {
    fn debug_buffer(buf: *const u8, len: u64);
}

#[no_mangle]
pub extern "C" fn bar() -> u8 {
    let s = "Hello from rust!";
    unsafe {
        debug_buffer(s.as_ptr(), s.len() as u64);
    }

    return 47;
}

use core::panic::PanicInfo;

/// This function is called on panic.
#[panic_handler]
fn panic(_info: &PanicInfo) -> ! {
    loop {}
}
