use std::process::exit;

use crate::pak_args::{parse_args, PakArgs, PakCommand};
use crate::pak_index::PakIndex;
use crate::pak_pack::pak_pack_index_path;
use crate::pak_unpack::pak_unpack_path;

const RESET: &str = "\x1b[0m";
const RED: &str = "\x1b[1;31m";
const GREEN: &str = "\x1b[1;32m";
const CHROMIUM_ASCII: &str = concat!(
    "\n\x1b[1;34m                .,:loool:,.\n",
    "            .,coooooooooooooc,.\n",
    "         .,lllllllllllllllllllll,.\n",
    "        ;ccccccccccccccccccccccccc;\n",
    "\x1b[1;36m      ,\x1b[1;34mccccccccccccccccccccccccccccc.\n",
    "\x1b[1;36m     ,oo\x1b[1;34mc::::::::ok\x1b[1;37m00000",
    "\x1b[0;37mOOkkkkkkkkkkk:\n",
    "\x1b[1;36m    .ooool\x1b[1;34m;;;;:x\x1b[1;37mK0",
    "\x1b[1;34mkxxxxxk\x1b[1;37m0X\x1b[0;37mK0000000000.\n",
    "\x1b[1;36m    :oooool\x1b[1;34m;,;O\x1b[1;37mK",
    "\x1b[1;34mddddddddddd\x1b[1;37mKX\x1b[0;37m000000000d\n",
    "\x1b[1;36m    lllllool\x1b[1;34m;l\x1b[1;37mN",
    "\x1b[1;34mdllllllllllld\x1b[1;37mN\x1b[0;37mK000000000\n",
    "\x1b[1;36m    lllllllll\x1b[1;34mo\x1b[1;37mM",
    "\x1b[1;34mdccccccccccco\x1b[1;37mW\x1b[0;37mK000000000\n",
    "\x1b[1;36m    ;cllllllllX\x1b[1;37mX\x1b[1;34mc:::::::::c",
    "\x1b[1;37m0X\x1b[0;37m000000000d\n",
    "\x1b[1;36m    .ccccllllllO\x1b[1;37mNk\x1b[1;34mc;,,,;cx",
    "\x1b[1;37mKK\x1b[0;37m0000000000.\n",
    "\x1b[1;36m     .cccccclllllxO\x1b[1;37mOOOO0\x1b[1;36mkx",
    "\x1b[0;37mO0000000000;\n",
    "\x1b[1;36m      .:ccccccccllllllllo\x1b[0;37mO0000000OOO,\n",
    "\x1b[1;36m        ,:ccccccccclllcd\x1b[0;37m0000OOOOOOl.\n",
    "\x1b[1;36m          .::ccccccccc\x1b[0;37mdOOOOOOOkx:.\n",
    "\x1b[1;36m            ..,::cccc\x1b[0;37mxOOOkkko;.\n",
    "\x1b[1;36m               ..::\x1b[0;37mdOkkxl:.\n\n",
    "\x1b[1;32m            Long Live Chromium!\x1b[0m\n\n",
);

mod pak_args;
mod pak_brotli;
mod pak_def;
mod pak_error;
mod pak_file;
mod pak_file_io;
mod pak_file_type;
mod pak_format;
mod pak_header;
mod pak_index;
mod pak_mmap;
mod pak_pack;
mod pak_unpack;

fn print_help(args: &PakArgs) {
    let default_name = String::from("pak");
    let self_name = args.self_name.as_ref().unwrap_or(&default_name);
    let mmap_availability = if crate::pak_mmap::MMAP_AVAILABLE {
        "available"
    } else {
        "unavailable"
    };
    match args.command {
        PakCommand::Unknown => println!("Unknown command"),
        PakCommand::Help | PakCommand::Version | PakCommand::ChromiumArt => {}
        PakCommand::Pack => println!("Incomplete pack arguments"),
        PakCommand::Unpack => println!("Incomplete unpack arguments"),
    }
    println!(include_str!("pak_help.txt"), self_name, mmap_availability);
}

fn main() {
    let args = parse_args();
    match args.command {
        PakCommand::Unknown => {
            print_help(&args);
            exit(2);
        }
        PakCommand::Help => print_help(&args),
        PakCommand::Version => {
            println!("Pak v{}", env!("CARGO_PKG_VERSION"));
        }
        PakCommand::ChromiumArt => print!("{}", CHROMIUM_ASCII),
        PakCommand::Pack => {
            if args.input_path.is_none() || args.output_path.is_none() {
                print_help(&args);
                exit(2);
            }
            match pak_pack_index_path(
                args.input_path.unwrap(),
                args.output_path.clone().unwrap(),
                args.edge_v5,
            ) {
                Err(err) => {
                    eprintln!("{}Error packing: {:?}{}", RED, err, RESET);
                    exit(1);
                }
                Ok(stats) => {
                    println!("\nresource_count = {}", stats.resource_count);
                    println!("alias_count = {}", stats.alias_count);
                    println!("version = {}", stats.version);
                    println!("encoding = {}", stats.encoding);
                    println!("\n.pak size: {} bytes", stats.total_size);
                    println!("{}\nPacked {}{}\n", GREEN, args.output_path.unwrap(), RESET,);
                }
            }
        }
        PakCommand::Unpack => {
            if args.input_path.is_none() || args.output_path.is_none() {
                print_help(&args);
                exit(2);
            }
            let input_path = args.input_path.unwrap();
            let output_path = args.output_path.unwrap();
            if let Err(err) = pak_unpack_path(
                input_path.clone(),
                output_path.clone(),
                args.edge_v5,
                args.mmap,
            ) {
                eprintln!("{}Error unpacking: {:?}{}", RED, err, RESET);
                exit(1);
            } else {
                println!(
                    "{}Unpacked {} to {}{}\n",
                    GREEN, input_path, output_path, RESET,
                );
            }
        }
    }
}
