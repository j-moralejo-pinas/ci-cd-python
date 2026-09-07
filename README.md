# ci-cd-python

Reusable GitHub Actions and repository setup scripts for Python projects
generated from [python-boilerplate](https://github.com/j-moralejo-pinas/python-boilerplate).

## Create a project

Install [GitHub CLI](https://cli.github.com/) and either install Copier or have
`uv` available:

```bash
copier copy https://github.com/j-moralejo-pinas/python-boilerplate.git my-project
```

For a new GitHub repository, the scripts in `scripts/` create the repository,
run Copier, and optionally configure branch rules:

```bash
scripts/create_repo.sh my-project "A short description" private
scripts/create_and_configure_repo.sh my-project "A short description" 3.13 github_flow
```

The full script accepts `public|private`, an optional exclusive maximum Python
version, and comma- or space-separated repository topics. It uses `uvx copier`
when Copier is not installed, and resolves the current `ci-cd-python` release
tag when rendering workflow references. Set `CI_CD_REF` to override it.

Generated repositories contain `.copier-answers.yml`. From one of those
repositories, run `copier update` to apply a newer template release and review
the resulting diff before committing.
