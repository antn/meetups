import { controller, target, attr } from "@github/catalyst"

// Example Catalyst web component.
//
// Usage in a view:
//   <hello-world data-catalyst>
//     <input data-target="hello-world.name" type="text">
//     <button data-action="click:hello-world#greet">Greet</button>
//     <span data-target="hello-world.output"></span>
//   </hello-world>
//
// `controller`, `target`, and `attr` are used here as plain functions/decorators
// so the component works under esbuild without decorator transforms enabled.
class HelloWorldElement extends HTMLElement {
  greet() {
    this.output.textContent = `Hello, ${this.name.value || "world"}!`
  }
}

target(HelloWorldElement.prototype, "name")
target(HelloWorldElement.prototype, "output")
attr(HelloWorldElement.prototype, "greeting")

controller(HelloWorldElement)

export default HelloWorldElement
