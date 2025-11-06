use crate::macros::internals_functions_generation::internal_functions_registry;

comptime fn generate_private_internal_function_call(f: FunctionDefinition) -> Quoted {
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
        pub fn $original_function_name(self, $original_params) -> $original_return_type {
            $fn_name(self.context, $params_at_callsite)
        }
    }
}

comptime fn generate_public_internal_function_call(f: FunctionDefinition) -> Quoted {
    let original_function_name = f.name();
    let original_return_type = f.return_type();
    let original_params = f
        .parameters()
        .map(|(param_name, param_type)| quote { $param_name: $param_type })
        .join(quote {, });

    let params_at_callsite =
        f.parameters().map(|(param_name, _)| quote { $param_name }).join(quote {, });

    let fn_name = f"__aztec_nr_internals__{original_function_name}".quoted_contents();

    // All public functions (both internal and external) are automatically made unconstrained, even if they were not
    // marked as such. This is because instead of compiling into a circuit, they will compile to bytecode that will be
    // later transpiled into AVM bytecode.
    quote {
        pub unconstrained fn $original_function_name(self, $original_params) -> $original_return_type {
            $fn_name(self.context, $params_at_callsite)
        }
    }
}

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
