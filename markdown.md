# Markdown

# *.md to *.html/*.pdf/... see chapter about pandoc

# How to edit Markdown (e.g. as used for GitLab/GitHub Wikis) offline using Gollum
1. install [Gollum](https://github.com/gollum/gollum/), e.g. with `apt-get install ruby && gem install gollum`
2. open a shell
3. navigate to your git repository folder
4. execute `gollum -h localhost --css`

# Links
[GitLab Flavored Markdown](https://gitlab.com/gitlab-org/gitlab-ce/blob/master/doc/markdown/markdown.md)

# Troubleshooting
### Tables are not being rendered properly in Gollum
Rerun
```
gem install gollum
gem install github-markdown
```
[Ref.](https://github.com/gollum/gollum/issues/907#issuecomment-162424080)
