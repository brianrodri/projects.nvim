local project_v1 = require("project-v1")

return {
    setup = project_v1.setup,
    add_project_manually = project_v1.add_project_manually,
    delete_project = project_v1.delete_project,
    get_recent_projects = project_v1.get_recent_projects,
    set_pwd = project_v1.set_pwd,
    get_options = project_v1.get_options,
}
