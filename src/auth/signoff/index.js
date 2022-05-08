// @deno-types="./index.d.ts"

import '../../core/index.js'

export let signoff = async () => {
    let a = await ajax({
        url: '/api/auth/signoff',
    })
    delete ajax.headers['Authorization']
    return a
}

