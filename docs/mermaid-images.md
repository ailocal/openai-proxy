# Generating Images from Mermaid Diagrams

## Installation

```bash
# Install mermaid-cli via npm
npm install -g @mermaid-js/mermaid-cli

# Or use Docker instead
docker pull minlag/mermaid-cli
```

## Basic Usage

### Using mmdc (if installed via npm)

```bash
# Generate PNG
mmdc -i input.md -o output.png -b transparent

# Generate SVG (recommended)
mmdc -i input.md -o output.svg -b transparent

# Control size
mmdc -i input.md -o output.png -w 800 -H 600
```

### Using Docker

```bash
# Generate PNG
docker run --rm -v $(pwd):/data minlag/mermaid-cli \
    -i /data/input.md \
    -o /data/output.png \
    -b transparent

# Generate SVG
docker run --rm -v $(pwd):/data minlag/mermaid-cli \
    -i /data/input.md \
    -o /data/output.svg \
    -b transparent
```

## Best Practices

1. **Use SVG format** when possible:
   - Perfect scaling at any size
   - Smaller file size
   - Crisp on all displays
   - Dark/light mode friendly

2. **Set background to transparent** (`-b transparent`)
   - Works better across different themes
   - Better integration with documentation

3. **Size Guidelines**:
   - README diagrams: 800px width max
   - Documentation: 1000px width max
   - Consider target display when sizing

4. **Keep source in docs**:
   - Store Mermaid source in markdown (e.g., `docs/diagrams/`)
   - Generate images to separate directory (e.g., `docs/images/`)
   - Include both in version control

## Example Workflow

```bash
# Create directories if needed
mkdir -p docs/images

# Generate SVG from markdown containing mermaid diagram
mmdc -i docs/architecture.md \
    -o docs/images/architecture.svg \
    -b transparent \
    -w 800

# Reference in README.md
# ![Architecture Diagram](docs/images/architecture.svg)
```
