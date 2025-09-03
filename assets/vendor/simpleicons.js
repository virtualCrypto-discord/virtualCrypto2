const plugin = require("tailwindcss/plugin")
const fs = require("fs")
const path = require("path")

module.exports = plugin(function ({ matchComponents, theme }) {
    let iconsDir = path.join(__dirname, "../../deps/simpleicons/icons")
    let values = {}
    fs.readdirSync(iconsDir).forEach(file => {
        let name = path.basename(file, ".svg")
        values[name] = { name, fullPath: path.join(iconsDir, file) }
    })
    matchComponents({
        "simple": ({ name, fullPath }) => {
            let content = fs.readFileSync(fullPath).toString().replace(/\r?\n|\r/g, "")
            let size = theme("spacing.6")
            return {
                [`--simple-${name}`]: `url('data:image/svg+xml;utf8,${content}')`,
                "-webkit-mask": `var(--simple-${name})`,
                "mask": `var(--simple-${name})`,
                "mask-repeat": "no-repeat",
                "vertical-align": "middle",
                "display": "inline-block",
                "width": size,
                "height": size
            }
        }
    }, { values })
})
