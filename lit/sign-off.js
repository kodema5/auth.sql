// an example sign-off
//
import { html } from 'https://kodema5.github.io/web-lit.js/lit.js'

import { AuthElement } from './auth-element.js'

export class SignOff extends AuthElement {
    render () {
        let me = this
        if (!me.isSigned) return null

        return html`
        <button type="button"
            class="btn btn-primary"
            @click=${async () => {
                let a = await me.signoff()
            }}
        >Sign Off</button>
        `
    }
}
