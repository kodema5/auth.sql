import {
    assert,
    assertEquals,
    assertStrictEquals,
    assertThrows,
} from "https://deno.land/std@0.136.0/testing/asserts.ts";
import {
    afterEach,
    beforeEach,
    describe,
    it,
} from "https://deno.land/std@0.136.0/testing/bdd.ts";


import './src/core/index.js'
ajax.base_href = 'http://localhost:8000'

import * as auth from './auth.js'

describe("auth", () => {
    it("signon", async () => {
        let r = await auth.signon({
            signon_name: 'test-signon-name',
            signon_password: 'foo'
        })

        assert(r.session_id)
        assert(ajax.headers['Authorization'])
    })

    it("signoff", async () => {
        await auth.signoff()
        assert(!ajax.headers['Authorization'])
    })
})

describe("auth", () => {
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
