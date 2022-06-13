export let signoff = async function () {

    let a = await this.ajax({
        url: '/api/auth/signoff',
        data: {},
    })

    if (a.errors) throw a.errors

    delete this.ajax.headers['Authorization']

    return a.data
}