import { assert, } from "https://deno.land/std@0.136.0/testing/asserts.ts";
import { describe, it, } from "https://deno.land/std@0.136.0/testing/bdd.ts";

import * as Ajax from 'https://raw.githubusercontent.com/kodema5/ajax.js/master/mod.js'
Ajax.ajax.base_href = 'http://localhost:8000'

import { Auth } from '../auth.js'
let auth = new Auth({ Ajax })


describe("signon-signoff", () => {
    it("signon", async () => {
        let r = await auth.signon({
            signon_name: 'test-signon-name',
            signon_password: 'foo'
        })

        assert(r.session_id)
        assert(Ajax.ajax.headers['Authorization'])
    })

    it("signoff", async () => {
        await auth.signoff()
        assert(!Ajax.ajax.headers['Authorization'])
    })
})


describe("register", () => {
    it("register", async () => {

        // existing may be inside
        try {
            let r = await auth.register({
                signon_name: 'foo',
                signon_password: 'bar'
            })

            assert(r.session_id)
            assert(ajax.headers['Authorization'])

            await auth.signoff()
            assert(!ajax.headers['Authorization'])
        } catch {}
    })

})

