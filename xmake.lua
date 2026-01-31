target("libf2c")
    set_kind("static")
    add_headerfiles("libf2c/f2c.h")
    add_includedirs("include", {public=true})
    add_files("libf2c/*.c")
    add_files("libf2c/*.cpp")
    remove_files("libf2c/arithchk.c")
    remove_files("libf2c/pow_qq.c")
    remove_files("libf2c/qbitbits.c")
    remove_files("libf2c/qbitshft.c")
    remove_files("libf2c/ftell64_.c")
    set_basename("f2c")
    if is_plat("windows", "mingw") then
        add_defines("MSDOS", "USE_CLOCK", "NO_ONEXIT", "NO_My_ctype", "NO_ISATTY")
    end
    if is_plat("windows") then 
        add_includedirs("libf2c/msvc")    
    end
    if is_plat("linux") then
        add_cxflags("-fPIC")
    end
    on_clean("windows", function(target)
        os.cd(path.join(os.scriptdir(), "libf2c"))
        os.rm("*.lib")
        os.rm("*.obj")
        os.rm("math.h")
        os.rm("f2c.h")
        os.rm("arith.h")
        os.rm("signal1.h")
        os.rm("sysdep1.h")
    end)
    on_build("windows", function (target)
        local olddir = os.curdir()
        os.cd(path.join(os.scriptdir(), "libf2c"))
        import("package.tools.nmake").build(target, {"/f", "makefile.vc"})
        os.cd(olddir)
        os.mkdir(target:targetdir())
        os.cp(path.join(os.scriptdir(), "libf2c", "vcf2c.lib"), target:targetfile())
        os.tryrm(path.join(os.scriptdir(), "libf2c", "math.h"))
    end)

    before_build("linux", function(target)
        if not os.exists("arith.h") then
            local cc = target:tool("cc")
            os.cd(path.join(os.scriptdir(), "libf2c"))
            try
            {
                function ()
                    local cmd = format("%s -DNO_FPINIT arithchk.c -lm", cc)
                    os.run(cmd)
                end,
                catch
                {
                    function (errors)
                        local cmd = format("%s -DNO_LONG_LONG -DNO_FPINIT arithchk.c -lm", cc)
                        os.run(cmd)
                    end
                }
            }
            os.execv("./a.out", {}, {stdout = "arith.h"})
        end
        os.cd(os.scriptdir())
        function prepare_file0(filepath)
            if not os.exists(filepath) then
                os.cp(filepath .. "0", filepath)
            end
        end
        prepare_file0("include/f2c.h")
        prepare_file0("libf2c/signal1.h")
        prepare_file0("libf2c/sysdep1.h")
        prepare_file0("libf2c/fio.h")
    end)

