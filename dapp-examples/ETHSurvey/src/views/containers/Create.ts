import { connect } from 'react-redux';

import { RootState } from '@src/redux/state';

import CreateSurvey from '@src/views/components/Create';

const mapStateToProps = (state: RootState, ownProps: {}) => {
  return { ...state };
};

export default connect<{}>(
  mapStateToProps,
  {}
)(CreateSurvey);
