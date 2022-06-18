export let register = async function ({
    signon_name,
    signon_password
}) {
    let a =  await this.ajax({
        url: '/api/auth/register',
        data: {
            signon_name,
            signon_password
        },
    })

    if (a.errors) throw a.errors

    let sid = this.ajax.headers['Authorization'] = a.data?.session_id
    return sid
}