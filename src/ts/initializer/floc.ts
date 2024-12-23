export default (ENV) => {
    return new Promise(function (resolve) {
        // @ts-ignore
        if (document.interestCohort !== undefined) {
            document
                // @ts-ignore
                .interestCohort()
                .then((cohort) => {
                    ENV.cohort = cohort;
                    resolve(ENV);
                })
                .catch((e) => {
                    resolve(ENV);
                });
        } else {
            resolve(ENV);
        }
    });
};
