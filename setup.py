
import os
from setuptools import setup, find_packages, Extension, find_packages

try:
    from Cython.Build import cythonize
except ImportError:
    cythonize = None


def get_option(name: str, default: bool = False):
    return (
        bool(int(os.getenv(name, default)))
        and cythonize is not None
    )

CYTHONIZE = get_option("CYTHONIZE")
INCL_NUMPY = get_option("INCL_NUMPY")
USE_CYTHON_TRACE = get_option("USE_CYTHON_TRACE")
USE_JACK_AUDIO = get_option("USE_JACK_AUDIO")

COMPILE_TIME_ENV = dict(
    CYSOUNDDEVICE_USE_JACK = USE_JACK_AUDIO,
)

os.environ['LDFLAGS'] = " ".join([
        "-framework CoreServices",
        "-framework CoreFoundation",
        "-framework AudioUnit",
        "-framework AudioToolbox",
        "-framework CoreAudio",
])


DEFINE_MACROS = [
    ('PD', 1),
    ('HAVE_UNISTD_H', 1),
    ('HAVE_LIBDL', 1),
    ('USEAPI_DUMMY', 1),
    ('LIBPD_EXTRA', 1),
]

if USE_CYTHON_TRACE:
    DEFINE_MACROS += [('CYTHON_TRACE_NOGIL', '1'), ('CYTHON_TRACE', '1')]



INCLUDE_DIRS = [
    # "/usr/local/include",
    "include",            
    "include/pd",
    "include/portaudio",
]


LIBRARIES = [
    'm',
    'dl',
    'pthread',
    'portaudio', # requires portaudio to be installed system-wide
]

LIBRARY_DIRS=[
    # '/usr/local/lib',
    'lib'
]




def no_cythonize(extensions, **_ignore):
    for extension in extensions:
        sources = []
        for sfile in extension.sources:
            path, ext = os.path.splitext(sfile)
            if ext in (".pyx", ".py"):
                if extension.language == "c++":
                    ext = ".cpp"
                else:
                    ext = ".c"
                sfile = path + ext
            sources.append(sfile)
        extension.sources[:] = sources
    return extensions


common = dict(
    define_macros = DEFINE_MACROS,
    include_dirs = INCLUDE_DIRS,
    libraries = LIBRARIES,
    library_dirs = LIBRARY_DIRS,
    # extra_objects=['lib/libpd.a'],
)

# def config_ext(name_tmpl, path_tmpl, **kwds):
#     def _func(name):
#         return Extension(
#             name_tmpl.format(name=name),
#             [path_tmpl.format(name=name)],
#             **kwds
#         )
#     return _func

# libpd_cfg = common.copy()
# libpd_cfg['extra_objects'] = ['lib/libpd.a']
# libpd_ext = config_ext("{name}", "src/libpd/{name}.pyx", **libpd_cfg)
# libpd_objs = ['libpd', 'pd']

# cydev_ext = config_ext("cysounddevice.{name}", "src/cysounddevice/{name}.pyx", **common)
# cydev_objs = ['buffer', 'conversion', 'devices', 'stream_callback', 
#               'streams', 'types', 'utils']

# extensions = [libpd_ext(i) for i in libpd_objs] + [cydev_ext(i) for i in cydev_objs]



cfg0 = common.copy()
cfg0['extra_objects'] = ['lib/libpd.a']

cfg1 = common.copy()
if INCL_NUMPY:
    import numpy
    try:
        import numpy
    except ImportError:
        numpy = None
    if numpy:
        cfg1['include_dirs'].append(numpy.get_include())




extensions = [
    # libpd
    Extension("libpd", ["src/libpd/libpd.pyx"], **cfg0),
    Extension("cypd",    ["src/libpd/cypd.pyx"], **cfg0),

    # csounddevice
    Extension("cysounddevice.buffer", ["src/cysounddevice/buffer.pyx"], **cfg1),
    Extension("cysounddevice.conversion", ["src/cysounddevice/conversion.pyx"], **cfg1),
    Extension("cysounddevice.devices", ["src/cysounddevice/devices.pyx"], **cfg1),
    Extension("cysounddevice.stream_callback", ["src/cysounddevice/stream_callback.pyx"], **cfg1),
    Extension("cysounddevice.streams", ["src/cysounddevice/streams.pyx"], **cfg1),
    Extension("cysounddevice.types", ["src/cysounddevice/types.pyx"], **cfg1),
    Extension("cysounddevice.utils", ["src/cysounddevice/utils.pyx"], **cfg1),
]


if CYTHONIZE:
    compiler_directives = {
        "language_level": 3, 
        "embedsignature": True,
        "binding": True,
    }
    extensions = cythonize(
        extensions,
        # annotate=True,
        # gdb_debug=True,
        compiler_directives=compiler_directives,
        compile_time_env=COMPILE_TIME_ENV)
else:
    extensions = no_cythonize(extensions)

with open("requirements.txt") as fp:
    install_requires = fp.read().strip().split("\n")

# with open("requirements-dev.txt") as fp:
#     dev_requires = fp.read().strip().split("\n")

setup(
    ext_modules=extensions,
    install_requires=install_requires,
    # extras_require={
    #     "dev": dev_requires,
    #     "docs": ["sphinx", "sphinx-rtd-theme"]
    # },
    package_dir={"": "src"},
    packages=find_packages(where="src"),
    python_requires=">=3.7",
)
