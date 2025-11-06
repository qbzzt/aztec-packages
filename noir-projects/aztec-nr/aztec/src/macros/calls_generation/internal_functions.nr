pub(crate) comptime fn generate_internal_functions_calls(m: Module) -> Quoted {
    let private_internal_functions = internal_functions_registry::get_private_functions(m);
    let public_internal_functions = internal_functions_registry::get_public_functions(m);

    let private_internal_functions_calls = private_internal_functions
        .map(|function| generate_private_internal_function_call(function))
        .join(quote {});
    let public_internal_functions_calls = public_internal_functions
        .map(|function| generate_public_internal_function_call(function))
        .join(quote {});

    quote {
        pub struct CallInternal<Context> {
            pub context: Context,
        }

        impl CallInternal<&mut aztec::context::private_context::PrivateContext> {
            $private_internal_functions_calls
        }

        impl CallInternal<aztec::context::public_context::PublicContext> {
            $public_internal_functions_calls
        }
    }
}

pub(crate) comptime fn generate_private_internal_function_call(f: FunctionDefinition) -> Quoted {
    let original_function_name = f.name();
    let original_return_type = f.return_type();
    let original_params = f
        .parameters()
        .map(|(param_name, param_type)| quote { $param_name: $param_type })
        .join(quote {, });

    let params_at_callsite =
        f.parameters().map(|(param_name, _)| quote { $param_name }).join(quote {, });

    let fn_name = f"__aztec_nr_internals__{original_function_name}".quoted_contents();

    quote {
        $original_function_name($original_params) -> $original_return_type {
            $fn_name(self.context, $params_at_callsite)
        }
    }
}

pub(crate) comptime fn generate_public_internal_function_call(f: FunctionDefinition) -> Quoted {
    quote {
        $f.name()
    }
}
