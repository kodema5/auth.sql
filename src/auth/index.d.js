type Signon = {
    signon_name:string
    signon_password:string
}
function signon(a:Signon): Promise<any>

function signoff(): Promise<any>

type Register = {
    signon_name:string
    signon_password:string
}
function register(a:Register): Promise<any>
