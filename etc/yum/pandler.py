from yum.plugins import PluginYumExit, TYPE_INTERACTIVE
import sys
import pprint

requires_api_version = '2.1'
plugin_type = (TYPE_INTERACTIVE,)

def config_hook(conduit):
    parser = conduit.getOptParser()
    if hasattr(parser, 'plugin_option_group'):
        parser = parser.plugin_option_group

def postresolve_hook(conduit):
    persistdir = conduit._base._conf.persistdir
    pkgs = [x[0] for x in conduit.getTsInfo().pkgdict.values()]

    file = open(persistdir+"/pandler.log", "w")
    for pkg in pkgs:
        relatedto_list = [x[0] for x in set(pkg.relatedto)]

        dic = {
            "package" : __pkg_to_s(pkg),
            "name"    : pkg.name,
            "version" : pkg.version,
            "release" : pkg.release,
            "arch"    : pkg.arch,
        }
        if len(relatedto_list) == 0:
            ltsv = u"\t".join(k + u":" + v for k, v in dic.iteritems())
            print(ltsv)
            file.write(ltsv + "\n")
        else:
            for relatedto in relatedto_list:
                dic["relatedto"] = __pkg_to_s(relatedto)
                ltsv = u"\t".join(k + u":" + v for k, v in dic.iteritems())
                print(ltsv)
                file.write(ltsv + "\n")

    file.close()

def postdownload_hook(conduit):
    opts, commands = conduit.getCmdLine()
    # Don't die on errors, or we'll never see them.
    if not conduit.getErrors():
        sys.exit(0)

def __pkg_to_s(pkg):
    name    = pkg.name
    version = pkg.version
    release = pkg.release
    arch    = pkg.arch
    return "%(name)s-%(version)s-%(release)s.%(arch)s" % locals()
