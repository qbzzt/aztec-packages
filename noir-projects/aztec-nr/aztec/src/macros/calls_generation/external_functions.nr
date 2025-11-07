use crate::macros::{
    calls_generation::call_interface_stubs::{
        create_private_self_call_stub, create_private_static_stub, create_private_stub,
        create_public_self_call_static_stub, create_public_self_call_stub,
        create_public_self_enqueue_static_stub, create_public_self_enqueue_stub,
        create_public_static_stub, create_public_stub, create_utility_stub,
    },
    internals_functions_generation::external_functions_registry,
    utils::is_fn_view,
};

pub(crate) comptime fn generate_external_function_calls(m: Module) -> Quoted {
    let private_functions = external_functions_registry::get_private_functions(m);
    let public_functions = external_functions_registry::get_public_functions(m);
    let utility_functions = external_functions_registry::get_utility_functions(m);

    let private_contract_methods = private_functions
        .map(|function| {
            if is_fn_view(function) {
                create_private_static_stub(function)
            } else {
                create_private_stub(function)
            }
        })
        .join(quote {});

    let public_contract_methods = public_functions
        .map(|function| {
            if is_fn_view(function) {
                create_public_static_stub(function)
            } else {
                create_public_stub(function)
            }
        })
        .join(quote {});

    let utility_contract_methods =
        utility_functions.map(|function| create_utility_stub(function)).join(quote {});

    quote {
        $private_contract_methods
        $public_contract_methods
        $utility_contract_methods
    }
}

pub(crate) comptime fn generate_external_function_self_calls(m: Module) -> Quoted {
    let private_functions = external_functions_registry::get_private_functions(m);
    let public_functions = external_functions_registry::get_public_functions(m);

    let call_self_private_methods = private_functions
        .map(|function| {
            if is_fn_view(function) {
                quote {}
            } else {
                create_private_self_call_stub(function, false)
            }
        })
        .join(quote {});

    let call_self_private_static_methods = private_functions
        .map(|function| {
            if is_fn_view(function) {
                create_private_self_call_stub(function, true)
            } else {
                quote {}
            }
        })
        .join(quote {});

    let call_self_public_methods = public_functions
        .map(|function| {
            if is_fn_view(function) {
                quote {}
            } else {
                create_public_self_call_stub(function)
            }
        })
        .join(quote {});

    let call_self_public_static_methods = public_functions
        .map(|function| {
            if is_fn_view(function) {
                create_public_self_call_static_stub(function)
            } else {
                quote {}
            }
        })
        .join(quote {});

    let enqueue_self_methods = public_functions
        .map(|function| {
            if is_fn_view(function) {
                quote {}
            } else {
                create_public_self_enqueue_stub(function)
            }
        })
        .join(quote {});

    let enqueue_self_static_methods = public_functions
        .map(|function| {
            if is_fn_view(function) {
                create_public_self_enqueue_static_stub(function)
            } else {
                quote {}
            }
        })
        .join(quote {});

    quote {
        pub struct CallSelf<Context> {
            pub address: dep::aztec::protocol_types::address::AztecAddress,
            pub context: Context,
        }

        impl CallSelf<&mut dep::aztec::context::private_context::PrivateContext> {
            $call_self_private_methods
        }

        impl CallSelf<dep::aztec::context::public_context::PublicContext> {
            $call_self_public_methods
        }

        pub struct CallSelfStatic<Context> {
            pub address: dep::aztec::protocol_types::address::AztecAddress,
            pub context: Context,
        }

        impl CallSelfStatic<&mut dep::aztec::context::private_context::PrivateContext> {
            $call_self_private_static_methods
        }

        impl CallSelfStatic<dep::aztec::context::public_context::PublicContext> {
            $call_self_public_static_methods
        }

        pub struct EnqueueSelf<Context> {
            pub address: dep::aztec::protocol_types::address::AztecAddress,
            pub context: Context,
        }

        impl EnqueueSelf<&mut dep::aztec::context::private_context::PrivateContext> {
            $enqueue_self_methods
        }

        pub struct EnqueueSelfStatic<Context> {
            pub address: dep::aztec::protocol_types::address::AztecAddress,
            pub context: Context,
        }

        impl EnqueueSelfStatic<&mut dep::aztec::context::private_context::PrivateContext> {
            $enqueue_self_static_methods
        }
    }
}
