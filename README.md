# Personal website with Hugo and GitHub Pages
A simple yet powerful Hugo-based static website hosted on a public Github page.

## References
- [Hugo Documentation](https://gohugo.io/documentation/)
- [PaperMod Theme Docs](https://github.com/adityatelange/hugo-PaperMod)
- [GitHub Pages Docs](https://docs.github.com/en/pages)

## Quick Start
Docker is used for Local Development
```bash
docker-compose up -d
```
Visit: http://localhost:1313

To rebuild and refresh the container:
```bash
docker-compose up --build
```

To restart the container:
```bash
docker-compose restart hugo
```

## Prerequisites
1. Git
2. Docker 

## Project Structure
```
hugo/
├── .github/
│   └── workflows/
│       └── deploy.yml          # GitHub Pages deployment
├── archetypes/
│   ├── default.md
│   ├── articles.md
│   └── projects.md
├── content/
│   ├── articles/               # Articles
│   ├── projects/               # Portfolio projects
│   ├── about.md
│   └── resume.md
├── data/
│   └── social.yml              # Social media links
├── layouts/
│   └── shortcodes/             # Custom shortcodes
├── static/
│   ├── images/
│   ├── files/                  # Resume, CV, etc.
│   └── favicon.ico
├── themes/
│   └── PaperMod/              # Git submodule
├── config.yml                 # Hugo configuration
├── docker-compose.yml         # Docker development
├── Dockerfile                 # Hugo container
└── .gitignore
```

## License
MIT License - feel free to use this template for your personal website.