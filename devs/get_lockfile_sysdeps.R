renv_lockfile_path <- here::here("renv.lock")
lockfile_json_content <- jsonlite::read_json(renv_lockfile_path)
project_pkgs <- names(lockfile_json_content$Packages)

options(pkg.sysreqs_platform = "ubuntu-22.04")

# pak::pkg_sysreqs(project_pkgs)
pak::pkg_sysreqs(c("units", "sf"))
